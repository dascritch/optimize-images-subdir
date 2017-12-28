# optimize-images-subdir


Having a bash script :

 -  Getting /images/last_exec_date
 -  Looking in /images/ for jpg files recentler than /images/last_exec_date
 -  On each new_image :
     -  if pathname in /images2/ doesn't exist, create subdirs
     -  copy new_image to /images2/
     -  jpeg-recompress new_image
 -   Ping /images/last_exec_date
