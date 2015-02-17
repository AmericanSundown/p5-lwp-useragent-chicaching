use Test::Perl::Critic(-exclude => [
											   'ProhibitUnusedPrivateSubroutines',
											   'RequireExtendedFormatting',
												'RequireArgUnpacking',
												'RequireUseStrict',
												'RequireUseWarnings'
											  ],
							  -severity => 3);
all_critic_ok();
