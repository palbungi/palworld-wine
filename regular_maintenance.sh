#!/bin/sh

RCON_PORT=25575
ADMIN_PASSWORD=palbungi1126

echo 'broadcast Auto_Reboot_Initialized' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
echo 'save' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
echo "shutdown 300 Server_is_going_to_reboot_in_5_minutes" | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 120
echo 'broadcast Server_is_going_to_reboot_in_3_minutes' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 60
echo 'broadcast Server_is_going_to_reboot_in_2_minutes' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 60
echo 'broadcast Server_is_going_to_reboot_in_60_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
echo 'save' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 50
echo 'broadcast Server_is_going_to_reboot_in_10_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 5
echo 'broadcast Server_is_going_to_reboot_in_5_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 1
echo 'broadcast Server_is_going_to_reboot_in_4_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 1
echo 'broadcast Server_is_going_to_reboot_in_3_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 1
echo 'broadcast Server_is_going_to_reboot_in_2_seconds' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
sleep 1
echo 'broadcast Server_is_going_to_reboot_in_1_second' | ARRCON -P $RCON_PORT -p $ADMIN_PASSWORD
