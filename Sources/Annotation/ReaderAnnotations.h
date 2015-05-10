//
// Created by otak on 20/02/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

// @see http://www.verypdf.com/document/pdf-format-reference/pg_0615.htm
#define kReaderAnnotationTypeLink "Link"
#define kReaderAnnotationTypeText "Text"
#define kReaderAnnotationTypeFreeText "FreeText"
#define kReaderAnnotationTypeSquare "Square"
#define kReaderAnnotationTypeCircle "Circle"
#define kReaderAnnotationTypeLine "Line"
#define kReaderAnnotationTypePolygon "Polygon"
#define kReaderAnnotationTypePolyLine "PolyLine"
#define kReaderAnnotationTypeHighlight "Highlight"
#define kReaderAnnotationTypeUnderline "Underline"
#define kReaderAnnotationTypeSquiggly "Squiggly"
#define kReaderAnnotationTypeStrikeOut "StrikeOut"
#define kReaderAnnotationTypeStamp "Stamp"
#define kReaderAnnotationTypeCaret "Caret"
#define kReaderAnnotationTypeInk "Ink"
#define kReaderAnnotationTypePopup "Popup"
#define kReaderAnnotationTypeFileAttachement "FileAttachement"
#define kReaderAnnotationTypeSound "Sound"
#define kReaderAnnotationTypeMovie "Movie"
#define kReaderAnnotationTypeWidget "Widget"
#define kReaderAnnotationTypeScreen "Screen"
#define kReaderAnnotationTypePrinterMark "PrinterMark"
#define kReaderAnnotationTypeTrapNet "TrapNet"
#define kReaderAnnotationTypeWatermark "Watermark"
#define kReaderAnnotationType3D "3D"

@interface ReaderAnnotations : NSObject

@property (strong, setter=setAnnotations:, nonatomic) NSMutableDictionary *annotations;

+(void)showAnotationImage:(CGPDFPageRef) pageRef inContext:(CGContextRef)context;

@end