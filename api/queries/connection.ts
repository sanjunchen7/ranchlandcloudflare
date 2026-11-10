import { drizzle, type MySql2Database } from "drizzle-orm/mysql2";
import { createConnection, type Connection, type ConnectionOptions } from "mysql2";
import * as fullSchema from "@db/schema";
import { currentRuntime, runtimeEnv } from "../lib/runtime";

type Database = MySql2Database<typeof fullSchema>;
type PromiseConnection = ReturnType<Connection["promise"]>;
type ScopedRuntime = NonNullable<ReturnType<typeof currentRuntime>> & {
  db?: Database;
  close?: () => Promise<void>;
};

let localInstance: Database | undefined;
let localConnection: PromiseConnection | undefined;

function workerConnection(options: string | ConnectionOptions): PromiseConnection {
  // Use mysql2's synchronous factory and promise facade so existing business
  // services can keep their synchronous getDb() access pattern. mysql2/promise's
  // current factory returns a Promise and would require rewriting every route.
  const connection = typeof options === "string" ? createConnection(options) : createConnection(options);
  return connection.promise();
}

export function getDb(): Database {
  const scoped = currentRuntime() as ScopedRuntime | undefined;
  if (scoped) {
    if (scoped.db) return scoped.db;
    const hyperdrive = scoped.env.HYPERDRIVE;
    const databaseUrl = scoped.env.DATABASE_URL;
    if (!hyperdrive && !databaseUrl) {
      throw new Error("No database configured. Set HYPERDRIVE in production or DATABASE_URL for local development.");
    }
    if (scoped.env.ENVIRONMENT === "production" && !hyperdrive) {
      throw new Error("Production database access requires the HYPERDRIVE binding.");
    }
    const useHyperdrive = Boolean(hyperdrive && (scoped.env.ENVIRONMENT === "production" || !databaseUrl));
    const promise = useHyperdrive
      ? workerConnection({
          host: hyperdrive!.host,
          port: hyperdrive!.port,
          user: hyperdrive!.user,
          password: hyperdrive!.password,
          database: hyperdrive!.database,
          disableEval: true,
        })
      : workerConnection(databaseUrl!);
    scoped.db = drizzle(promise, { mode: "planetscale", schema: fullSchema });
    scoped.close = () => promise.end();
    return scoped.db;
  }

  const databaseUrl = runtimeEnv().DATABASE_URL;
  if (!databaseUrl) throw new Error("DATABASE_URL is required for local database scripts.");
  if (!localInstance) {
    localConnection = workerConnection(databaseUrl);
    localInstance = drizzle(localConnection, { mode: "planetscale", schema: fullSchema });
  }
  return localInstance;
}

export async function closeLocalDb(): Promise<void> {
  if (!localConnection) return;
  await localConnection.end();
  localConnection = undefined;
  localInstance = undefined;
}
