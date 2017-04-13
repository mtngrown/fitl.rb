-- figure out how to compute coin control

drop view if exists us_totals;
drop view if exists arvn_totals;
drop view if exists vc_totals;
drop view if exists nva_totals;
drop view if exists fwa_totals;
drop view if exists non_nva_totals;
drop view if exists controls_first_try;
drop view if exists controls;

create view if not exists us_totals (name, total)
  as select locations.name, us_troop + us_base + us_irregular
  as total from locations where total > 0;

create view if not exists vc_totals (name, total)
  as select locations.name, vc_guerrilla + vc_base + vc_tunnel_base
  as total from locations where total > 0;

create view if not exists arvn_totals (name, total)
  as select locations.name, arvn_troop + arvn_base + arvn_ranger + arvn_police
  as total from locations where total > 0;

create view if not exists nva_totals (name, total)
  as select locations.name, nva_troop + nva_base + nva_tunnel_base + nva_guerrilla
  as total from locations where total > 0;

create view if not exists fwa_totals(name, total)
  as select us_totals.name, us_totals.total + arvn_totals.total
  from us_totals join arvn_totals on us_totals.name = arvn_totals.name;

create view if not exists non_nva_totals(name, total)
  as select fwa_totals.name, fwa_totals.total + vc_totals.total
  from fwa_totals join vc_totals on fwa_totals.name = vc_totals.name;

create view if not exists controls_first_try(name, control) as
  select nva_totals.name,
    CASE
    WHEN (nva_totals.total > non_nva_totals.total) THEN 'NVA'
    WHEN (fwa_totals.total > nva_totals.total) THEN 'COIN'
    ELSE
      'NONE'
    END
  from nva_totals join non_nva_totals on nva_totals.name = non_nva_totals.name join fwa_totals on fwa_totals.name = nva_totals.name;

create view if not exists controls(name, control) as select
  name, CASE
    WHEN us_troop + us_base + us_irregular + arvn_troop + arvn_base + arvn_ranger + arvn_police
      > nva_troop + nva_base + nva_tunnel_base + nva_guerrilla + vc_guerrilla + vc_base + vc_tunnel_base THEN 'COIN'
    WHEN nva_base + nva_tunnel_base + nva_guerrilla
      > us_base + us_irregular + arvn_troop + arvn_base + arvn_ranger + arvn_police + vc_guerrilla + vc_base + vc_tunnel_base THEN 'NVA'
    ELSE 'NONE'
    END
  from locations where location_type = 'province' OR location_type = 'city';
