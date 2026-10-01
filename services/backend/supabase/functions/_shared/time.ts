import { ApiError } from "./errors.ts";

/// Calendar day and wall-clock time of [date] in an IANA time zone.
export function localParts(date: Date, timezone: string) {
  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    }).formatToParts(date);
  } catch (_) {
    throw new ApiError("INVALID_INPUT", "timezone is not valid", 400, false, {
      field: "timezone",
    });
  }
  const part = (type: string) =>
    Number(parts.find((item) => item.type === type)?.value ?? 0);
  const pad = (value: number, width = 2) =>
    value.toString().padStart(width, "0");
  return {
    day: `${pad(part("year"), 4)}-${pad(part("month"))}-${pad(part("day"))}`,
    hour: part("hour"),
    minute: part("minute"),
    second: part("second"),
  };
}

/// The UTC instant at which clocks in [timezone] read [hour]:[minute] on
/// [day] (YYYY-MM-DD).
export function zonedTimeToUtc(
  day: string,
  hour: number,
  minute: number,
  timezone: string,
) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(day);
  if (!match) {
    throw new ApiError("INVALID_INPUT", "day must be YYYY-MM-DD", 400, false, {
      field: "day",
    });
  }
  const wall = Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    hour,
    minute,
  );
  // Two passes settle the offset across a daylight-saving change.
  let instant = wall;
  for (let pass = 0; pass < 2; pass++) {
    instant = wall - offsetAt(instant, timezone);
  }
  return new Date(instant);
}

/// Timestamp for a meal logged now into the thread for [day]. Today's thread
/// gets the real instant; another day's thread gets the same local clock time
/// on that day.
export function loggedAtForDay(
  day: string,
  timezone: string,
  now = new Date(),
) {
  const local = localParts(now, timezone);
  if (local.day === day) return now.toISOString();
  return zonedTimeToUtc(day, local.hour, local.minute, timezone).toISOString();
}

function offsetAt(instant: number, timezone: string) {
  const local = localParts(new Date(instant), timezone);
  const [year, month, day] = local.day.split("-").map(Number);
  const asUtc = Date.UTC(
    year,
    month - 1,
    day,
    local.hour,
    local.minute,
    local.second,
  );
  return asUtc - Math.floor(instant / 1000) * 1000;
}
