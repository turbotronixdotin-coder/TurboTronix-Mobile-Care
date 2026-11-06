insert into public.mobile_brands(name) values
('Apple'),('Samsung'),('Vivo'),('OPPO'),('Realme'),('Redmi'),('POCO'),('OnePlus'),('iQOO'),('Motorola'),('Nothing'),('Google Pixel')
on conflict (name) do nothing;

insert into public.repair_categories(name, description) values
('Display','Screen and display replacement'),
('Battery','Battery replacement and diagnosis'),
('Charging','Charging port and charging issues'),
('Audio','Speaker and microphone issues'),
('Camera','Front and rear camera issues'),
('Software','Software troubleshooting and installation'),
('Other','Other inspection and repair')
on conflict (name) do nothing;

insert into public.business_settings(id, business_name, currency)
values (1, 'TurboTronix Mobile Care', 'INR')
on conflict (id) do nothing;

insert into public.repair_services(name,description) values
('Display replacement','Screen or display replacement'),('Battery replacement','Battery replacement and health diagnosis'),('Charging port replacement','Charging connector replacement'),('Back panel replacement','Rear panel replacement'),('Camera replacement','Front or rear camera replacement'),('Speaker replacement','Speaker replacement'),('Microphone replacement','Microphone replacement'),('Fingerprint sensor replacement','Fingerprint sensor replacement or calibration'),('Software installation','OS or firmware installation'),('Water damage inspection','Diagnostic water-damage inspection'),('Motherboard diagnosis','Motherboard fault diagnosis'),('Other hardware repair','Other repair subject to inspection')
except select name,description from public.repair_services;

-- Add one seed model per supported brand; owner can dynamically manage all catalogue records in the app.
insert into public.mobile_models(brand_id,model_name,model_number)
select b.id,b.name || ' Demo Model',b.name || '-MODEL-1'
from public.mobile_brands b
where not exists(select 1 from public.mobile_models m where m.brand_id=b.id)
on conflict(brand_id,model_name) do nothing;

insert into public.service_slots(weekday,start_time,end_time) values
(1,'09:00','12:00'),(1,'12:00','15:00'),(1,'15:00','18:00'),(1,'18:00','21:00'),
(2,'09:00','12:00'),(2,'12:00','15:00'),(2,'15:00','18:00'),(2,'18:00','21:00'),
(3,'09:00','12:00'),(3,'12:00','15:00'),(3,'15:00','18:00'),(3,'18:00','21:00'),
(4,'09:00','12:00'),(4,'12:00','15:00'),(4,'15:00','18:00'),(4,'18:00','21:00'),
(5,'09:00','12:00'),(5,'12:00','15:00'),(5,'15:00','18:00'),(5,'18:00','21:00'),
(6,'09:00','12:00'),(6,'12:00','15:00'),(6,'15:00','18:00'),(6,'18:00','21:00');

insert into public.model_services(model_id,service_id,estimated_labour)
select m.id,s.id,case when s.name='Motherboard diagnosis' then 499 else 299 end
from public.mobile_models m cross join public.repair_services s
on conflict(model_id,service_id) do nothing;

insert into public.model_service_prices(model_service_id,quality_grade,spare_part_price,doorstep_charge)
select ms.id,q.grade,
 case when ms.service_id in (select id from repair_services where name='Display replacement') then q.display_price else q.default_price end,
 199
from public.model_services ms cross join (values
 ('Original Service Pack',8999,3499),('OEM',4999,2499),('Compatible',2999,1499),('AMOLED',6999,3499),('OLED',6499,2999),('Incell',3999,1999),('LCD',2999,1499)
) as q(grade,display_price,default_price)
where ms.estimated_labour>0
on conflict(model_service_id,quality_grade) do nothing;
