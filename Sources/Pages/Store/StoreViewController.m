//
//  StoreViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 08.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "StoreViewController.h"
#import "DetailViewController.h"

@interface StoreViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableViewItem;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end



@implementation StoreViewController

#pragma mark - View Lifecicle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableViewItem.autoresizingMask = UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.tableViewItem = nil;
    self.fetchedResultsController = nil;
}

#pragma mark - Вспомогательные методы

+ (NSDateFormatter*)visualDateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [NSLocale currentLocale];
    [df setDateFormat:@"d MMMM yyyy HH:mm"];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"MSK"]];
    return df;
}

#pragma mark - Методы NSFetchedResultsController

/**
 *  Метод для формирования fetchedResultsController'a
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    _fetchedResultsController = [PhotoModel MR_fetchAllSortedBy:@"createdDate"
                                                      ascending:NO
                                                  withPredicate:nil
                                                        groupBy:nil
                                                       delegate:self];
    
    _fetchedResultsController.fetchRequest.fetchBatchSize = kMagicalRecordDefaultBatchSize;
    
    NSError *error = nil;
    if ([_fetchedResultsController performFetch:&error] == NO) {
        NSLog(@"fetch error: %@", error);
    }
    
    return _fetchedResultsController;
}

/**
 *  Метод, уведомляющий о начале работы fetch-контроллера
 */
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // разрешаем асинхронное обновление ячеек таблицы
    [self.tableViewItem beginUpdates];
}

/**
 *  Метод, уведомляющий об окончании работы fetch-контроллера
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // запрещаем асинхронное обновление ячеек таблицы
    [self.tableViewItem endUpdates];
}

/**
 *  Метод, уведомляющий fetch-контроллер об изменении объекта
 */
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)theType
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (theType) {
        case NSFetchedResultsChangeInsert:
            [self.tableViewItem insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableViewItem reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableViewItem deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableViewItem moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
            
        default:
            break;
    }
}

/**
 * Количество элементов в заданной секции
 */
- (NSInteger)countOfItemsForSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

#pragma mark - Методы UITableView DataSource

/**
 *  Метод возвращает количество ячеек в таблице
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self countOfItemsForSection:section];
}

/**
 *  Метод возвращает ячейку таблицы по указанному адресу
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StoreCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:StoreCellIdentifier];
    }
    
    PhotoModel *model = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell.imageView setImage:model.photo];
    [cell.textLabel setText:[[StoreViewController visualDateFormatter] stringFromDate:[model createdDate]]];
    
    return cell;
}

#pragma mark - Методы UIStoryboardSegue

/**
 *  Метод подготовки переходов между текущим контроллером и дочерними
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // обработка нажатия по ячейке таблицы - переход к деталке
    if ([segue.identifier isEqualToString:@"PushSegueFromStoreVCToDetailVC"]) {
        NSIndexPath *index_path = [self.tableViewItem indexPathForSelectedRow];
        [self.tableViewItem deselectRowAtIndexPath:index_path animated:YES];
        
        DetailViewController *detail_vc = segue.destinationViewController;
        [detail_vc setPhotoModel:[self.fetchedResultsController objectAtIndexPath:index_path]];
    }
}

@end
