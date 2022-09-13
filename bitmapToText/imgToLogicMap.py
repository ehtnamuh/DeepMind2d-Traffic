import numpy as np
from matplotlib.image import imread

colorToSymbol = {"#ffffff": "*",
                     "#ff0000": "p",
                     "#000000": " "}


def colorToSymbolMap(colorString, colorToSymbolDict=colorToSymbol):
    if colorString in colorToSymbolDict.keys():
        return colorToSymbolDict[colorString]
    else:
        print("invalid color entry, spawning empty space")
        return " "


def clamp(x):
    x = int(x * 255)
    return max(0, min(x, 255))


def rgbToSymbol(r, g, b):
    colorHexString = "#{0:02x}{1:02x}{2:02x}".format(clamp(r), clamp(g), clamp(b))
    return colorToSymbolMap(colorHexString)


def main():
    img = imread("img.png")
    symbolMap = ""
    for line in img:
        myLine = ""
        for pixel in line:
            r, g, b = pixel[0], pixel[1], pixel[2]
            myLine += rgbToSymbol(r, g, b)
        symbolMap = symbolMap + myLine + "\n"
    print(symbolMap)


if __name__ == "__main__":
    main()
