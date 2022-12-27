import type { NextApiRequest, NextApiResponse } from "next";

type ResponseData = {
  message: string;
};

/**
 * Api handler for /api/heartbeat
 * Used for https://github.com/ubiquity/ubiquity-dollar/issues/343
 * @param req http request
 * @param res http response
 */
export default function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  res.status(200).json({ message: "ok" });
}
