//
//  ETNewsViewController.m
//  TongXunLu
//
//  Created by teach on 14-9-1.
//  Copyright (c) 2014年 dhb. All rights reserved.
//

#import "ETNewsViewController.h"
#import "txlAppDelegate.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"

#import "Member.h"
#import "News.h"

#import "NewsTableViewCell.h"
#import "ETNewsDetailViewController.h"

@interface ETNewsViewController ()

@end
static NSString *NewsIdentify = @"NewsCell";
@implementation ETNewsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithHostMember:(Member *)member
{
    self = [super init];
    if (self) {
        host = member;
    }
    return  self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect frame = [(txlAppDelegate *)[UIApplication sharedApplication].delegate viewFrame:self.navigationController withTabBarController:self.tabBarController];
    self.tableView = [[UITableView alloc] initWithFrame:frame];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsTableViewCell" bundle:nil] forCellReuseIdentifier:NewsIdentify];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载中..."];
    [self.refreshControl addTarget:self action:@selector(refreshTableView) forControlEvents:UIControlEventValueChanged];
    _newsList = [[NSMutableArray alloc] init];
    [self dowithNewsList];
}

-(void)refreshTableView
{
    [self dowithNewsList];
}

-(void)dowithNewsList
{
    [_newsList removeAllObjects];
    NSString *url = [NSString stringWithFormat:@"http://121.40.88.201/interface/get_message.php?userid=%@&password=%@&from=0&size=100&label=新闻",host.userId,host.userPsd];
    NSString *encodedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setCompletionBlock:^{
        NSString *responseStr = [request responseString];
        NSDictionary *dic = [responseStr objectFromJSONString];
        NSDictionary *resultDic = [dic objectForKey:@"result"];
        NSInteger code = [[resultDic objectForKey:@"code"] integerValue];
        if (code == 100) {
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSArray *dataArr = [dataDic objectForKey:@"array"];
            @try {
                for (id m in dataArr) {
                    News *news = [[News alloc] init];
                    news.publicTime = [m objectForKey:@"publishTime"];
                    news.title = [m objectForKey:@"title"];
                    news.messageId = [m objectForKey:@"messageId"];
                    news.content = [m objectForKey:@"content"];
                    news.readState = [[m objectForKey:@"isread"] boolValue];
                    [_newsList addObject:news];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
            }
            @finally {
                
            }
            
            [self.tableView reloadData];
            if ([self.refreshControl isRefreshing])
            {
                [self.refreshControl endRefreshing];
            }
        }else{
            NSLog(@"加载失败...");
        }
    }];
    [request setFailedBlock:^{
        NSLog(@"网络错误");
    }];
    [request startAsynchronous];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _newsList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NewsIdentify];
    if (cell == nil) {
        cell = [[NewsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NewsIdentify];
    }
    
    News *news = [_newsList objectAtIndex:indexPath.row];
    [cell setUpCellWithNews:news];
    // Configure the cell...
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 172.0f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    News *news = [_newsList objectAtIndex:indexPath.row];
    ETNewsDetailViewController *etNewsDetailVC = [[ETNewsDetailViewController alloc] initWithHostMember:host WithNews:news];
    [self.navigationController pushViewController:etNewsDetailVC animated:YES];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
#pragma mark - ICSDrawerControllerPresenting

- (void)drawerControllerWillOpen:(ICSDrawerController *)drawerController
{
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidOpen:(ICSDrawerController *)drawerController
{
    self.view.userInteractionEnabled = YES;
}

- (void)drawerControllerWillClose:(ICSDrawerController *)drawerController
{
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidClose:(ICSDrawerController *)drawerController
{
    self.view.userInteractionEnabled = YES;
}

@end
