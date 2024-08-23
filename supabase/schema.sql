
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auth_user_id" "uuid" NOT NULL,
    "stripe_customer_id" "text",
    "is_pro" boolean DEFAULT false NOT NULL,
    "subscription_id" "text",
    "firstname" "text",
    "lastname" "text",
    "curr_period_end" "date",
    "avatar_url" "text",
    "auto_renew" boolean DEFAULT false NOT NULL,
    "subscription_status" "text"
);

ALTER TABLE "public"."customers" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "content" "text" NOT NULL,
    "path" "text" NOT NULL,
    "user_id" "uuid" NOT NULL
);

ALTER TABLE "public"."feedback" OWNER TO "postgres";

ALTER TABLE "public"."feedback" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."feedback_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "short_uid" "text" NOT NULL,
    "name" "text" NOT NULL,
    "thumbnail" "text",
    "fpath" "text" NOT NULL,
    "ispnid" boolean NOT NULL,
    "width" bigint NOT NULL,
    "height" bigint NOT NULL,
    "ftype" "text" NOT NULL,
    "project" "uuid" NOT NULL,
    "viewable" boolean DEFAULT false NOT NULL
);

ALTER TABLE "public"."files" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."nodes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "short_uid" "text" NOT NULL,
    "name" "text",
    "pos_x" numeric NOT NULL,
    "pos_y" numeric NOT NULL,
    "width" numeric NOT NULL,
    "height" numeric NOT NULL,
    "equipment_type" "text" NOT NULL,
    "metadata" "json",
    "pnid" "uuid" NOT NULL,
    "color" "text" NOT NULL,
    "shape" "text" NOT NULL,
    "verified" boolean
);

ALTER TABLE "public"."nodes" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "short_uid" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "thumbnail" "text",
    "owner" "uuid" NOT NULL,
    "viewable" boolean DEFAULT false NOT NULL
);

ALTER TABLE "public"."projects" OWNER TO "postgres";

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customer_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customer_stripe_customer_id_key" UNIQUE ("stripe_customer_id");

ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_short_uid_key" UNIQUE ("short_uid");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_short_uid_key" UNIQUE ("short_uid");

ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_short_uid_key" UNIQUE ("short_uid");

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_auth_user_id_fkey" FOREIGN KEY ("auth_user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."files"
    ADD CONSTRAINT "files_project_fkey" FOREIGN KEY ("project") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."nodes"
    ADD CONSTRAINT "nodes_pnid_fkey" FOREIGN KEY ("pnid") REFERENCES "public"."files"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_owner_fkey" FOREIGN KEY ("owner") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Enable CRUD for nodes based on auth" ON "public"."nodes" USING ((( SELECT "auth"."uid"() AS "uid") IN ( SELECT "p"."owner"
   FROM ("public"."files" "f"
     JOIN "public"."projects" "p" ON (("f"."project" = "p"."id")))
  WHERE ("f"."id" = "nodes"."pnid"))));

CREATE POLICY "Enable delete for users based on user_id" ON "public"."feedback" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));

CREATE POLICY "Enable delete for users based on user_id" ON "public"."projects" FOR DELETE USING ((( SELECT "auth"."uid"() AS "uid") = "owner"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."feedback" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."projects" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "owner"));

CREATE POLICY "Enable select for authenticated users only" ON "public"."customers" FOR SELECT TO "authenticated" USING (true);

CREATE POLICY "Enable select for users based on user_id" ON "public"."projects" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "owner"));

CREATE POLICY "Enable update for users based on auth_user_id" ON "public"."customers" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "auth_user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "auth_user_id"));

CREATE POLICY "Enable update for users based on user_id" ON "public"."projects" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "owner")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "owner"));

CREATE POLICY "Enable view for files where viewable is true" ON "public"."files" FOR SELECT USING (("viewable" = true));

CREATE POLICY "Only allow project owners to CRUD" ON "public"."files" USING ((( SELECT "auth"."uid"() AS "uid") IN ( SELECT "projects"."owner"
   FROM "public"."projects"
  WHERE ("projects"."id" = "files"."project"))));

CREATE POLICY "allow nodes to appear in viewable files" ON "public"."nodes" FOR SELECT USING ((( SELECT "files"."viewable"
   FROM "public"."files"
  WHERE ("files"."id" = "nodes"."pnid")) = true));

CREATE POLICY "allow viewable projects to show" ON "public"."projects" FOR SELECT USING (("viewable" = true));

ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."files" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."nodes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;

ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON TABLE "public"."customers" TO "anon";
GRANT ALL ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";

GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";

GRANT ALL ON SEQUENCE "public"."feedback_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."feedback_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."feedback_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."files" TO "anon";
GRANT ALL ON TABLE "public"."files" TO "authenticated";
GRANT ALL ON TABLE "public"."files" TO "service_role";

GRANT ALL ON TABLE "public"."nodes" TO "anon";
GRANT ALL ON TABLE "public"."nodes" TO "authenticated";
GRANT ALL ON TABLE "public"."nodes" TO "service_role";

GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
