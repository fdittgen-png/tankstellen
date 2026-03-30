// ntfy.sh push notification helper.
// ntfy is a simple HTTP-based pub/sub notification service.
// Users subscribe to a topic in their ntfy app; we POST messages to that topic.

export interface NtfyOptions {
  /** ntfy topic (unique per user/device) */
  topic: string;
  /** Notification title */
  title: string;
  /** Notification body text */
  message: string;
  /** Priority: min, low, default, high, max */
  priority?: 'min' | 'low' | 'default' | 'high' | 'max';
  /** Comma-separated tags/emojis (e.g. "fuelpump,warning") */
  tags?: string;
  /** Optional click URL when user taps the notification */
  clickUrl?: string;
}

/**
 * Sends a push notification via ntfy.sh.
 *
 * @param options - Notification configuration
 * @throws Error if the ntfy request fails
 */
export async function sendNtfyNotification(options: NtfyOptions): Promise<void> {
  const { topic, title, message, priority = 'high', tags = 'fuelpump', clickUrl } = options;

  const headers: Record<string, string> = {
    'Title': title,
    'Priority': priority,
    'Tags': tags,
  };

  if (clickUrl) {
    headers['Click'] = clickUrl;
  }

  const response = await fetch(`https://ntfy.sh/${topic}`, {
    method: 'POST',
    headers,
    body: message,
  });

  if (!response.ok) {
    const body = await response.text();
    console.error(`ntfy.sh error: ${response.status} — ${body}`);
    throw new Error(`Failed to send ntfy notification: ${response.status}`);
  }
}

/**
 * Convenience: send a fuel price alert notification.
 */
export async function sendPriceAlertNotification(
  topic: string,
  stationName: string,
  fuelType: string,
  currentPrice: number,
  thresholdPrice: number,
): Promise<void> {
  const priceStr = currentPrice.toFixed(3);
  const thresholdStr = thresholdPrice.toFixed(3);

  await sendNtfyNotification({
    topic,
    title: `Tankstellen: ${fuelType} price alert`,
    message: `${stationName}: ${fuelType} is now ${priceStr} EUR/L (your threshold: ${thresholdStr} EUR/L)`,
    priority: 'high',
    tags: 'fuelpump,chart_with_downwards_trend',
  });
}
