import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ region: "us-central1" });
admin.initializeApp();

const HYSTERESIS_METERS = 50;

type ProximityState = "in_range" | "out_of_range";

interface ParticipantDoc {
  displayName?: string;
  role?: "runner" | "spectator";
  thresholdMeters?: number;
  fcmToken?: string;
  location?: { latitude: number; longitude: number };
  proximityState?: Record<string, ProximityState>;
}

function haversineMeters(
  a: { latitude: number; longitude: number },
  b: { latitude: number; longitude: number }
): number {
  const R = 6371000;
  const dLat = ((b.latitude - a.latitude) * Math.PI) / 180;
  const dLon = ((b.longitude - a.longitude) * Math.PI) / 180;
  const lat1 = (a.latitude * Math.PI) / 180;
  const lat2 = (b.latitude * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

async function sendProximityPush(
  token: string,
  title: string,
  body: string
): Promise<void> {
  await admin.messaging().send({
    token,
    notification: { title, body },
    apns: {
      headers: {
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
          "interruption-level": "time-sensitive",
        },
      },
    },
  });
}

export const onParticipantLocationUpdate = onDocumentUpdated(
  "sessions/{sessionCode}/participants/{participantId}",
  async (event) => {
    const before = event.data?.before.data() as ParticipantDoc | undefined;
    const after = event.data?.after.data() as ParticipantDoc | undefined;
    if (!after?.location) return;

    const locationChanged =
      before?.location?.latitude !== after.location.latitude ||
      before?.location?.longitude !== after.location.longitude;
    if (!locationChanged) return;

    const sessionCode = event.params.sessionCode;
    const updatedId = event.params.participantId;
    const db = admin.firestore();

    const participantsSnap = await db
      .collection("sessions")
      .doc(sessionCode)
      .collection("participants")
      .get();

    const participants = participantsSnap.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as ParticipantDoc),
    }));

    const runner = participants.find((p) => p.role === "runner");
    if (!runner?.location) return;

    const updated = participants.find((p) => p.id === updatedId);
    if (!updated?.location) return;

    for (const observer of participants) {
      if (!observer.location || !observer.fcmToken) continue;

      let subject: typeof runner | undefined;
      let distance: number;

      if (observer.role === "runner" && updated.role === "spectator") {
        subject = updated;
        distance = haversineMeters(runner.location, updated.location);
      } else if (observer.role === "spectator" && updated.role === "runner") {
        subject = runner;
        distance = haversineMeters(observer.location!, runner.location);
      } else if (
        observer.role === "spectator" &&
        updated.role === "spectator" &&
        observer.id === updatedId
      ) {
        subject = runner;
        distance = haversineMeters(observer.location!, runner.location);
      } else {
        continue;
      }

      const threshold = observer.thresholdMeters ?? 200;
      const enterThreshold = threshold;
      const exitThreshold = threshold + HYSTERESIS_METERS;

      const stateKey = subject.id;
      const currentState = observer.proximityState?.[stateKey] ?? "out_of_range";
      const isInRange =
        currentState === "in_range"
          ? distance <= exitThreshold
          : distance <= enterThreshold;

      const newState: ProximityState = isInRange ? "in_range" : "out_of_range";

      if (currentState === "out_of_range" && newState === "in_range") {
        const name = subject.displayName ?? "Someone";
        await sendProximityPush(
          observer.fcmToken,
          `${name} is nearby!`,
          `About ${Math.round(distance)} m away — look up!`
        );
      }

      if (currentState !== newState) {
        await db
          .collection("sessions")
          .doc(sessionCode)
          .collection("participants")
          .doc(observer.id)
          .update({
            [`proximityState.${stateKey}`]: newState,
          });
      }
    }
  }
);
