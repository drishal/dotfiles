ff1 = open("xmobar-dracula.hs", "r")
f1 = ff1.readlines()
f2 = open("xmobar-palenight.hs", "w")

checkWords = (
     "#282a36",  # 0  Background
     "#44475a",  # 1  current line/lighter_black
     "#f8f8f2",  # 2  foreground
     "#6272a4",  # 3  comment/dark_grey
     "#8be9fd",  # 4  cyan
     "#50fa7b",  # 5  green
     "#ffb86c",  # 6  orange 
     "#ff79c6",  # 7  pink    
     "#bd93f9",  # 8  purple
     "#ff5555",  # 9  red
     "#f1fa8c",  # 10 yellow 
      
)
repWords = (
     "#292D3E", # 0 background
     "#242837", # 1 bg-alt
     "#EEFFFF", # 2 foreground
     "#676E95", # 3 dark grey / comments
     "#80cbc4", # 4 cyan
     "#c3e88d", # 5 green 
     "#f78c6c", # 6 orange 
     "#c792ea", # 7 magenta
     "#bb80b3", # 8 violet
     "#ff5370", # 9 red 
     "#ffcb6b", # 10 yellow 
)

for line in f1:
    for check, rep in zip(checkWords, repWords):
        line = line.replace(check, rep)
    f2.write(line)
