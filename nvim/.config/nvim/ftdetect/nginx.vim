au BufRead,BufNewFile */nginx*/*,/tmp/*
      \ if getline(1)=~'^\s*server\s*{'
      \ | setf nginx

