today=`date +%Y-%m-%d.%H:%M:%S`

php artisan serve --host=192.168.1.30 --port=8000  > log/run/Start_at_${today}.log 2>&1 &
