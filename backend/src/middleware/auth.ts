import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;

/**
 * Auth guard for all routes that act on a specific user's data.
 *
 * Requires a verified "Authorization: Bearer <jwt>" - it does NOT accept a raw
 * x-user-id header, since that's just a client-supplied string anyone could set
 * to any value to read or modify another user's data. On success it overwrites
 * req.headers["x-user-id"] with the userId from the verified token, so downstream
 * controllers (which all read req.header("x-user-id")) get a trustworthy value.
 */
export function requireVerifiedUser(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.header("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : undefined;

  if (!token) {
    return res.status(401).json({ error: "Authentication required" });
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
