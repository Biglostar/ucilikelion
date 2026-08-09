import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;

/**
 * Transitional auth middleware.
 *
 * If a verified "Authorization: Bearer <jwt>" is present, it overwrites the
 * x-user-id header with the userId from the token, so downstream controllers
 * (which all read req.header("x-user-id")) get a value that's actually been
 * verified instead of one supplied unchecked by the client.
 *
 * If no bearer token is present, the raw x-user-id header is left as-is so
 * the app keeps working while the frontend is migrated to send the token.
 * TODO: once the frontend sends Authorization on every request, remove the
 * x-user-id fallback and reject requests without a valid token.
 */
export function resolveUserId(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.header("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : undefined;

  if (!token) {
    return next();
  }

  if (!JWT_SECRET) {
    console.error("JWT_SECRET is not set; cannot verify bearer token");
    return res.status(500).json({ error: "Server auth misconfigured" });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: string };
    req.headers["x-user-id"] = payload.userId;
    return next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function signUserToken(userId: string): string {
  if (!JWT_SECRET) {
    throw new Error("JWT_SECRET is not set");
  }
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: "30d" });
}
