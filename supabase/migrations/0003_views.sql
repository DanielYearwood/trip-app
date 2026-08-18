-- =========================================================
-- 0003_views.sql — vistas de conveniencia para el presupuesto
-- security_invoker = true para que hereden la RLS de las tablas base.
-- Ver README.md sección 7.3.
-- =========================================================

create or replace view public.v_budget_summary as
select
  e.trip_id,
  sum(coalesce(e.amount_eur, e.amount)) filter (where e.status <> 'cancelado')   as previsto_eur,
  sum(coalesce(e.amount_eur, e.amount)) filter (where e.status = 'comprometido') as comprometido_eur,
  sum(e.amount_paid)                                                             as pagado_eur,
  sum(coalesce(e.amount_eur, e.amount) - e.amount_paid)
      filter (where e.status not in ('cancelado','reembolsado'))                 as pendiente_eur
from public.expenses e
where e.deleted_at is null
group by e.trip_id;

create or replace view public.v_budget_by_category as
select
  trip_id,
  category,
  sum(coalesce(amount_eur, amount)) as total_eur,
  sum(amount_paid)                  as pagado_eur
from public.expenses
where deleted_at is null and status <> 'cancelado'
group by trip_id, category;

create or replace view public.v_settlement as
select
  e.trip_id,
  e.paid_by as user_id,
  sum(e.amount_paid) as aportado_eur
from public.expenses e
where e.deleted_at is null and e.amount_paid > 0
group by e.trip_id, e.paid_by;

alter view public.v_budget_summary     set (security_invoker = true);
alter view public.v_budget_by_category set (security_invoker = true);
alter view public.v_settlement          set (security_invoker = true);
