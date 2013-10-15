//
//  PhotoModel+Addition.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "PhotoModel+Addition.h"

@implementation PhotoModel (Addition)

+ (id)findByPK:(NSNumber*)pk
{
    return [self MR_findFirstByAttribute:@"pk" withValue:pk];
}

+ (id)createEntity:(UIImage*)image createdDate:(NSDate*)createdDate
{
    // извлекаем ID последней созданной сущности PhotoModel из настроек пользователя
    NSNumber *pk = [[NSUserDefaults standardUserDefaults] objectForKey:PhotoModelIDKey];
    if (pk == nil) {
        pk = @0;
    }
    
    // увеличиваем на единицу (аналог автоинкремента в СУБД)
    pk = @(pk.intValue+1);
    
    // в БД не должно существовать модели с таким PrimaryKey
    PhotoModel *model = [self findByPK:pk];
    if (model != nil) {
        NSAssert(YES, @"Entity of PhotoModel with pk=%d already exists", pk.intValue);
    }
    
    // сохраняем текущий PK в настройках пользователя
    [[NSUserDefaults standardUserDefaults] setObject:pk forKey:PhotoModelIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // преобразуем к NSData для последующего вычисления размера изображения
    NSData *img_data = UIImageJPEGRepresentation(image, 1.f);
    
    // создаем сущность
    model = [self MR_createEntity];
    model.pk = pk;
    model.photo = image;
    model.createdDate = createdDate;
    model.fileSize = @([img_data length]);
    
    return model;
}

@end
