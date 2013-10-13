//
//  ImageToDataTransformer.m
//  delpress
//
//  Created by Ildar Sibagatov on 22.09.13.
//  Copyright (c) 2013 DigiPeople Inc. All rights reserved.
//

#import "ImageToDataTransformer.h"

@implementation ImageToDataTransformer

/**
 *  Получатель может обратить преобразование
 */
+ (BOOL)allowsReverseTransformation
{
	return YES;
}

/**
 *  Класс объекта, полученного при обратном преобразовании получателем
 */
+ (Class)transformedValueClass
{
	return [NSData class];
}

/**
 *  Возвращает результат прямого преобразования объекта
 */
- (id)transformedValue:(id)value
{
	return UIImageJPEGRepresentation(value, 1.f);
}

/**
 *  Возвращает результат обратного преобразования объекта
 */
- (id)reverseTransformedValue:(id)value
{
	return [[UIImage alloc] initWithData:value];
}

@end