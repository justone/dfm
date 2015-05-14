requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Slurp', 0;
    requires 'Test::Trap', 0;
};

