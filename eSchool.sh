#!/bin/bash
gnome-terminal --tab --title="laravel" --command="bash -c 'cd /var/www/laravel/eSchool; ls;bash serve.sh;code ./;  $SHELL'"
gnome-terminal --tab --title="vuejs" --command="bash -c 'cd /var/www/vue/eSchool; ls;bash serve.sh;code ./; $SHELL'"
exit;
