package org.PDFCreator;

public class PDFGenerationParams {
    String inputFilePath;
    String replacement;
    String fontType;
    int fontSize;
    int centerX;
    int centerY;
    String fontFilePath;
    String outputFileName;

    /**
     * Constructs a new PDFGenerationParams object with the given parameters.
     *
     * @param inputFilePath The path of the input file.
     * @param replacement The replacement text.
     * @param fontType The type of the font.
     * @param fontSize The size of the font.
     * @param centerX The x-coordinate of the center.
     * @param centerY The y-coordinate of the center.
     * @param fontFilePath The path of the font file.
     * @param outputFileName The name of the output file.
     */
    public PDFGenerationParams(String inputFilePath, String replacement, String fontType, int fontSize,
                           int centerX, int centerY, String fontFilePath, String outputFileName) {
        this.inputFilePath = inputFilePath;
        this.replacement = replacement;
        this.fontType = fontType;
        this.fontSize = fontSize;
        this.centerX = centerX;
        this.centerY = centerY;
        this.fontFilePath = fontFilePath;
        this.outputFileName = outputFileName;
    }

     /**
     * Creates a new instance of PDFGenerationParams with the given parameters.
    */
    public static PDFGenerationParams createInstance(String inputFilePath, String replacement, String fontType, int fontSize,
                           int centerX, int centerY, String fontFilePath, String outputFileName) {
        return new PDFGenerationParams(inputFilePath, replacement, fontType, fontSize, centerX, centerY, fontFilePath, outputFileName);
    }
}
