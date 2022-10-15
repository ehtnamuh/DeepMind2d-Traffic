from matplotlib.image import imread
import os

color_to_symbol = {"#ffffff": "*",
                   "#ff0000": "1",
                   "#0000ff": "2",
                   "#000000": " "
                 }


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
        my_line = ""
        for pixel in line:
            r, g, b = pixel[0], pixel[1], pixel[2]
            my_line += rgb_to_symbol(r, g, b)
        symbol_map = symbol_map + my_line + "\n"
    return symbol_map


def write_map_to_file(logic_map, map_name, save_location=""):
    path = os.path.join(save_location,map_name)
    f = open(path, "w")
    f.write(logic_map)
    f.close()


def main():
    # save_path = "/home/samin/Desktop/Projects/DeepMind2d/DeepMind2d-Traffic/dmlab2d/lib/game_scripts/levels/traffic_norms/text_maps"
    save_path = "../dmlab2d/lib/game_scripts/levels/traffic_norms/text_maps"
    a = os.path.join(os.path.abspath(os.getcwd()) + "/imageMaps/roadTriggers2.png")
    img = imread(a)
    logic_map = img_to_logic_map(img)
    write_map_to_file(logic_map, "roadTriggers.txt", save_path)


if __name__ == "__main__":
    main()
