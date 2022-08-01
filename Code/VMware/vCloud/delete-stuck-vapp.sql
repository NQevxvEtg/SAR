select * from vm_container where name like '%vAPPNAMEStringHERE%';

delete from vm_container where sg_id = 0xHEX;

select * from dbo.vapp_logical_resource where vapp_id = 0xHEX;

select vapp_logical_resource.id from vm_container inner join vapp_logical_resource on vm_container.sg_id = vapp_logical_resource.vapp_id where vm_container.name = 'FullvAPPNAMEStringHERE';

0xHEX
0xHEX
0xHEX
0xHEX

delete from vapp_logical_resource where id = 0xHEX;
delete from vapp_logical_resource where id = 0xHEX;
delete from vapp_logical_resource where id = 0xHEX;
delete from vapp_logical_resource where id = 0xHEX;

select * from dbo.vapp_vm where vapp_id = 0xHEX;

delete from vapp_vm where id = 0xHEX;

select * from dbo.vapp_vm_sclass_metrics where vapp_vm_id = 0xHEX;

delete from vapp_vm_sclass_metrics where vapp_vm_id = 0xHEX;

select * from dbo.guest_personalization_info where vapp_vm_id = 0xHEX;

delete from guest_personalization_info where vapp_vm_id = 0xHEX;
