"""Champion-first scaling: equal direct-damage action pools, independent utility."""
AD_CHAMPIONS={'minotaur','golem','troll','wendigo','direwolf','manticore','griffin','wyvern','harpy','nemean','owlbear','hydra','cerberus','chimera','jackalope','cyclops'}
UTILITY={'ward','rally','renew','fear','bulwark','shellup','prideroar','frostroar','radiance','rootbloom','tidal','regrowth','tailwind','hunger','howl','brood'}
def rebalance(book):
 counts={'ad':0,'ap':0,'utility':0};champions={}
 for sp,actions in book.items():
  channel='ad' if sp in AD_CHAMPIONS else 'ap'
  champions[sp]={'path':channel.upper(),'damage_actions':0}
  for action in actions.values():
   old=action['scaling'];action['build_path']=channel
   if action['effect'] in UTILITY:
    p={k:v for k,v in old.items() if k not in {'ad','ap'}}
    p[channel]=old.get('ad',0)+old.get('ap',0)
    counts['utility']+=1
   else:
    p={k:min(v,.35) for k,v in old.items() if k in {'armor','hp'}}
    defensive=sum(p.values())
    if defensive>.35:p={k:v*.35/defensive for k,v in p.items()}
    p[channel]=round(1-sum(p.values()),4)
    if 'as' in old:p['as']=old['as']
    counts[channel]+=1;champions[sp]['damage_actions']+=1
   action['scaling']=p
 return {'counts':counts,'champions':champions,'rule':'Direct-damage actions are 174 AD and 174 AP. Utility actions keep defensive channels and their champion primary channel. Damage type remains thematic and independent of the scaling stat.'}
