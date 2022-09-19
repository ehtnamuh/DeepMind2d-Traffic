from matplotlib.image import imread

color_to_symbol = {"#ffffff": "*",
                   "#ff0000": "b",
                   "#00ff00": "e",
                   "#0000ff": "n",
                   "#ffff00": "p",
                   "#000000": " "}


def color_to_symbol_map(color_string, color_to_symbol_dict=None):
    if color_to_symbol_dict is None:
        color_to_symbol_dict = color_to_symbol
    if color_string in color_to_symbol_dict.keys():
        return color_to_symbol_dict[color_string]
    else:
        print("invalid color entry, spawning empty space")
        return " "


def clamp(x):
    x = int(x * 255)
    return max(0, min(x, 255))


def rgb_to_symbol(r, g, b):
    color_hex_string = "#{0:02x}{1:02x}{2:02x}".format(clamp(r), clamp(g), clamp(b))
    return color_to_symbol_map(color_hex_string)


def img_to_logic_map(img):
    symbol_map = ""
    for line in img:
        myLine = ""
        for pixel in line:
            r, g, b = pixel[0], pixel[1], pixel[2]
            myLine += rgb_to_symbol(r, g, b)
        symbol_map = symbol_map + myLine + "\n"
    return symbol_map


def write_map_to_file(logic_map, map_name):
    f = open(map_name, "w")
    f.write(logic_map)
    f.close()


def main():
    img = imread("playerSpawns.png")
    logic_map = img_to_logic_map(img)
    write_map_to_file(logic_map, "playerSpawns.txt")
    img = imread("roadLogic.png")
    logic_map = img_to_logic_map(img)
    write_map_to_file(logic_map, "roadLogic.txt")


if __name__ == "__main__":
    main()
