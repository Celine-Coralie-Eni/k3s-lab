// @generated automatically by Diesel CLI.

diesel::table! {
    tasks (id) {
        id -> Uuid,
        title -> Varchar,
        description -> Nullable<Text>,
        completed -> Bool,
        user_id -> Uuid,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::table! {
    users (id) {
        id -> Uuid,
        username -> Varchar,
        email -> Varchar,
        password_hash -> Varchar,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

diesel::joinable!(tasks -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    tasks,
    users,
);


