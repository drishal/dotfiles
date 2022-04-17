ff1 = open("dracula.conkyrc", "r")
f1 = ff1.readlines()
f2 = open("onedark.conkyrc", "w")

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
     "#282c34", # 0 background
     "#3f444a", # 1 bg-alt
     "#bbc2cf", # 2 foreground
     "#5B6268", # 3 dark grey / comments
     "#46d9ff", # 4 cyan
     "#98be65", # 5 green 
     "#da8548", # 6 orange 
     "#c678dd", # 7 magenta
     "#a9a1e1", # 8 violet
     "#ff6c6b", # 9 red 
     "#ecbe7b", # 10 yellow 
)

for line in f1:
    for check, rep in zip(checkWords, repWords):
        line = line.replace(check, rep)
    f2.write(line)
