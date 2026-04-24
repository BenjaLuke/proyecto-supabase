-- EXTENSION PARA UUID
create extension if not exists "uuid-ossp";

--------------------------------------------------
-- TABLA: categories
--------------------------------------------------
create table categories (
    id uuid primary key default uuid_generate_v4(),
    code text not null,
    name text not null,
    description text,
    parent_id uuid,
    created_at timestamp default now(),

    constraint fk_parent
        foreign key (parent_id)
        references categories(id)
        on delete set null
);

--------------------------------------------------
-- TABLA: products
--------------------------------------------------
create table products (
    id uuid primary key default uuid_generate_v4(),
    code text not null,
    name text not null,
    description text,
    created_at timestamp default now()
);

--------------------------------------------------
-- TABLA: product_categories
--------------------------------------------------
create table product_categories (
    product_id uuid,
    category_id uuid,

    primary key (product_id, category_id),

    constraint fk_product
        foreign key (product_id)
        references products(id)
        on delete cascade,

    constraint fk_category
        foreign key (category_id)
        references categories(id)
        on delete cascade
);

--------------------------------------------------
-- TABLA: product_rates
--------------------------------------------------
create table product_rates (
    id uuid primary key default uuid_generate_v4(),
    product_id uuid not null,
    start_date date not null,
    end_date date,
    price numeric(10,2) not null,
    created_at timestamp default now(),

    constraint fk_product_rates
        foreign key (product_id)
        references products(id)
        on delete cascade
);

--------------------------------------------------
-- TABLA: product_images
--------------------------------------------------
create table product_images (
    id uuid primary key default uuid_generate_v4(),
    product_id uuid not null,
    image_path text not null,
    sort_order integer default 0,
    created_at timestamp default now(),

    constraint fk_product_images
        foreign key (product_id)
        references products(id)
        on delete cascade
);

--------------------------------------------------
-- TABLA: purchase_orders
--------------------------------------------------
create table purchase_orders (
    id uuid primary key default uuid_generate_v4(),
    order_date date not null,
    product_id uuid not null,
    units integer not null,
    unit_price numeric(10,2) not null,
    total_cost numeric(10,2) not null,
    created_at timestamp default now(),

    constraint fk_purchase_product
        foreign key (product_id)
        references products(id)
        on delete cascade
);