//
//  Annotation.h
//  readerpdf
//
//  Created by Jesús López on 10/11/13.
//  Copyright (c) 2013 Viafirma S.L. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Annotation : NSObject

typedef enum annotationTypes
{
	SIGNATURE,
	SIGNATURE_USER_IMAGE,
	IMAGE
} AnnotationType;

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic) CGPoint point;
@property (nonatomic) CGRect frame;
@property (nonatomic,strong) NSNumber *page;
@property (nonatomic) AnnotationType type;

@end
