package TestController;
use BoogieWoogie::Controller;
extends 'BoogieWoogie::Controller::Base';

action foo => sub {
    'Hello world!';
};

1;
