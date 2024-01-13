ff1 = open("dracula.Xresources", "r")
f1 = ff1.readlines()
f2 = open("OneDark.Xresources", "w")

checkWords = (
     "#282A36",  # 0  Background
     "#44475A",  # 1  current line/lighter_black
     "#F8F8F2",  # 2  foreground
     "#6272A4",  # 3  comment/dark_grey
     "#8BE9FD",  # 4  cyan
     "#50FA7B",  # 5  green
     "#FFB86C",  # 6  orange 
     "#FF79C6",  # 7  pink    
     "#BD93F9",  # 8  purple
     "#FF5555",  # 9  red
     "#F1FA8C",  # 10 yellow 
      
)
repWords = (
     "#282C34", # 0 background
     "#3F444A", # 1 bg-alt
     "#BBC2CF", # 2 foreground
     "#5B6268", # 3 dark grey / comments
     "#46D9FF", # 4 cyan
     "#98BE65", # 5 green 
     "#DA8548", # 6 orange 
     "#C678DD", # 7 magenta
     "#A9A1E1", # 8 violet
     "#FF6C6B", # 9 red 
     "#ECBE7B", # 10 yellow 
)

for line in f1:
    for check, rep in zip(checkWords, repWords):
        line = line.replace(check, rep)
    f2.write(line)
