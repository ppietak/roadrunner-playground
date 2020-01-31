<?php

namespace App\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class LambdaCommand extends Command
{
    protected function configure()
    {
        $this
            ->setName('app:lambda')
            ->addArgument('body', InputArgument::REQUIRED);
    }

    public function execute(InputInterface $input, OutputInterface $output)
    {
        $body = $input->getArgument('body');
        $output->writeln('Event body is: ' . $body);
    }
}
