command! -nargs=? Qiita :call qiita#Qiita(<f-args>)
command! CtrlPQiita cal ctrlp#init(ctrlp#qiita#id())
