-- figure out how to compute coin control

drop view if exists us_totals;
drop view if exists arvn_totals;
drop view if exists vc_totals;
drop view if exists nva_totals;

create view if not exists us_totals (name, total) as select locations.name, us_troop + us_base + us_irregular as total from locations where total > 0;
create view if not exists vc_totals (name, total) as select locations.name, vc_guerrilla + vc_base + vc_tunnel_base as total from locations where total > 0;
create view if not exists arvn_totals (name, total) as select locations.name, arvn_troop + arvn_base + arvn_ranger + arvn_police as total from locations where total > 0;
create view if not exists nva_totals (name, total) as select locations.name, nva_troop + nva_base + nva_tunnel_base + nva_guerrilla as total from locations where total > 0;
