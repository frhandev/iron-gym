BEGIN;
INSERT INTO "Roles"(role_name,description) VALUES
 ('Üye','Gym member'),
 ('Eğitmen','Class trainer'),
 ('Resepsiyon Personeli','Reception staff'),
 ('Yönetici','Gym administrator')
 ON CONFLICT(role_name) DO NOTHING;
INSERT INTO "MembershipPackages"(package_name,duration_months,price,description) VALUES
 ('Basic',1,1000.00,'One-month membership'),
 ('Gold',3,2700.00,'Three-month membership'),
 ('Premium',12,9600.00,'Twelve-month membership')
 ON CONFLICT(package_name) DO NOTHING;
INSERT INTO "Rooms"(room_name,capacity) VALUES
 ('Yoga Room',20),('Pilates Room',15),('Fitness Studio',30)
 ON CONFLICT(room_name) DO NOTHING;
INSERT INTO "GroupClasses"(class_name,description) VALUES
 ('Yoga','Flexibility and breathing'),
 ('Pilates','Core and controlled movement'),
 ('Spinning','Group indoor cycling')
 ON CONFLICT(class_name) DO NOTHING;
COMMIT;
