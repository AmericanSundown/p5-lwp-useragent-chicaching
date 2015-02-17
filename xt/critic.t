use Test::Perl::Critic(-exclude => [
											   'ProhibitUnusedPrivateSubroutines',
											   'RequireExtendedFormatting',
												'RequireArgUnpacking'
											  ],
							  -severity => 3);
all_critic_ok();
