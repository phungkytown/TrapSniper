//
//  SetttingsViewController.m
//  TrapSniper
//
//  Created by Hai Phung on 11/11/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import "SetttingsViewController.h"

@interface SetttingsViewController ()

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic) UISwitch *GPSSwitch;

@end

@implementation SetttingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Table View Data Source / Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
    
    // Configure the cell...
    self.GPSSwitch = [[UISwitch alloc] init];
    [self.GPSSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"useGPS"] animated:NO];
    [self.GPSSwitch addTarget:self action:@selector(onGPSSwitchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.GPSSwitch;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Location Services";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enabling GPS will improve accuracy at the expense of battery life. (Not recommended)";
    }
    return nil;
}


#pragma mark - Actions

- (void)onGPSSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [self.userDefaults setBool:YES forKey:@"useGPS"];
    } else {
        [self.userDefaults setBool:NO forKey:@"useGPS"];
    }
}

- (IBAction)onDoneButtonTapped:(id)sender {
    [self.userDefaults synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Accessors

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}

@end
