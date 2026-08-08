function value = paperText(key)
%PAPERTEXT Decode Chinese paper labels from ASCII-safe UTF-8 hex.
%   MATLAB R2016a on Chinese Windows may read UTF-8 M-files using the
%   system code page.  Keeping this source ASCII-only prevents mojibake.

switch key
    case 'inverse_title', hex = 'e58d95e8beb9e7958ce688aae696ade4bb8be8b4a8e79a84e98086e59091e681a2e5a48de4b88ee6ada3e59091e9878de694be';
    case 'inverse_left_title', hex = 'e98086e59091e681a2e5a48defbc9ae7bcbae5a4b1e995bfe5baa6e7ad89e4ba8e35303030e5878fe8a782e5af9fe995bfe5baa6';
    case 'inverse_left_sub', hex = 'e585a8e983a8e7bcbae5a4b1e995bfe5baa6e6b2bfe8beb9e7958ce782b9e4b98be5908ee7bba7e7bbade5bbb6e4bcb8';
    case 'interior', hex = 'e58685e983a8e7abafe782b9';
    case 'boundary', hex = 'e8beb9e7958ce782b9';
    case 'recovered_endpoint', hex = 'e681a2e5a48de7abafe782b9';
    case 'observed', hex = 'e99984e4bbb6e8a782e5af9fe6aeb5';
    case 'recovered_missing', hex = 'e681a2e5a48de79a84e7bcbae5a4b1e983a8e58886';
    case 'forward_replay', hex = 'e6ada3e59091e9878de694bee9878de696b0e7949fe68890e99984e4bbb6e8a782e5af9fe6aeb5';
    case 'zero_translation', hex = 'e99984e4bbb6e8a782e5af9fe6aeb5efbc88e99bb6e5b9b3e7a7bbefbc89';
    case 'wrapped_piece', hex = 'e5b9b3e7a7bbe5908ee79a84e8b68ae7958ce58886e6aeb5';
    case 'real_title', hex = 'e4b889e7bb84e99984e4bbb6e4b8ade58d95e8beb9e7958ce4bb8be8b4a8e79a84e79c9fe5ae9ee681a2e5a48de6a188e4be8b';
    case 'real_group_fmt', hex = 'e7bb842564efbc9ae4bb8be8b4a8412564efbc88457863656ce7acac2564e8a18cefbc89';
    case 'real_lengths_fmt', hex = 'e8a782e5af9fe995bfe5baa63d252e3366efbc8ce7bcbae5a4b1e995bfe5baa63d252e3366e7bab3e7b1b3';
    case 'real_legend', hex = 'e8939de889b2efbc9ae99984e4bbb6e8a782e5af9fe6aeb5efbc9be7baa2e889b2e8999ae7babfefbc9ae681a2e5a48de79a84e5ae8ce695b4e4bb8be8b4a8efbc9be5bda9e889b2efbc9ae8beb9e7958ce5a484e79086e5908ee79a84e4bb8be8b4a8e58886e6aeb5';
    case 'status_title', hex = 'e99984e4bbb6e4bb8be8b4a8e9878de69e84e78ab6e68081e7bb9fe8aea1';
    case 'structure1', hex = 'e5beaee69e84e4bd9331';
    case 'structure2', hex = 'e5beaee69e84e4bd9332';
    case 'structure3', hex = 'e5beaee69e84e4bd9333';
    case 'medium_count', hex = 'e99984e4bbb6e4bb8be8b4a8e695b0e9878f';
    case 'direct', hex = 'e79bb4e68ea5e5ae8ce695b4e4bb8be8b4a8';
    case 'single', hex = 'e58d95e8beb9e7958ce681a2e5a48d';
    case 'two_amb', hex = 'e58f8ce8beb9e7958ce5be85e5ae9a';
    case 'no_boundary', hex = 'e697a0e6ada3e5bc8fe8beb9e7958ce5be85e5ae9a';
    case 'replay_fail', hex = 'e6ada3e59091e9878de694bee5a4b1e8b4a5';
    case 'piece_title', hex = 'e594afe4b880e681a2e5a48de4bb8be8b4a8e79a84e8beb9e7958ce58886e6aeb5e695b0e9878fe7bb9fe8aea1';
    case 'unique_count', hex = 'e594afe4b880e681a2e5a48de4bb8be8b4a8e695b0e9878f';
    case 'one_piece', hex = '31e4b8aae58886e6aeb5';
    case 'two_piece', hex = '32e4b8aae58886e6aeb5';
    case 'three_piece', hex = '33e4b8aae58886e6aeb5';
    case 'four_piece', hex = '34e4b8aae58886e6aeb5';
    case 'charge_title', hex = 'e4bb8be8b4a8e5b8a6e794b5e78ab6e68081e4b88ee79c9fe5ae9ee5afbce9809ae8b7afe5be84e79a84e58cbae588ab';
    case 'charge_only', hex = 'e5908ce4b880e4bb8be8b4a8efbc9ae4bb85e7bba7e689bfe5b8a6e794b5e78ab6e68081';
    case 'charged_not_connected', hex = 'e5b8a6e794b5e4b88de7ad89e4ba8ee8bf9ee9809a';
    case 'no_hidden', hex = 'e5908ce4b880e4bb8be8b4a8e79a84e58886e6aeb5e4b98be997b4e6b2a1e69c89e99a90e8978fe5afbce794b5e8beb9';
    case 'real_edges', hex = 'e79c9fe5ae9ee5afbce9809ae5bf85e9a1bbe794b1e69c89e99990e59c86e69fb1e68ea5e8a7a6e8beb9e7bb84e68890';
    case 'path_desc', hex = 'e5b7a6e794b5e69e81e588b0e4bb8be8b4a8e58886e6aeb5e5868de588b0e58fb3e794b5e69e81';
    case 'upper_title', hex = 'e5beaee69e84e4bd9331e69caae7a1aee5ae9ae4bb8be8b4a8e79a84e4b990e8a782e587a0e4bd95e4b88ae7958ce9aa8ce8af81';
    case 'upper_sub', hex = 'e689a9e5a4a7e58c85e7bb9ce4b88ee5aebde69dbee883b6e59b8ae588a4e68daee4b88be4bb8de4b88de5ad98e59ca8e5b7a6e58fb3e8b4afe9809ae8b7afe5be84';
    case 'observed_fmt', hex = '412564e8a782e5af9fe6aeb5';
    case 'cert_fmt', hex = 'e69c80e5b08fe58c85e7bb9c2de5b7b2e79fa5e58886e6aeb5e8bdb4e8b79defbc9a252e3666e7bab3e7b1b35c6ee69c80e5b08fe58c85e7bb9c2de58c85e7bb9ce8bdb4e8b79defbc9a252e3666e7bab3e7b1b35c6ee5afbce9809ae8bdb4e8b79de58585e58886e4b88ae7958cefbc9a32522b64303d252e3166e7bab3e7b1b35c6ee4b990e8a782e4b88ae7958ce59bbee5afbce9809aefbc9ae590a6';
    case 'cert_note', hex = 'e58db3e4bdbfe98787e794a8e689a9e5a4a7e5908ee79a84e587a0e4bd95e58c85e7bb9ce5928ce69bb4e5aebde69dbee79a84e883b6e59b8ae68ea5e8a7a6e588a4e68daeefbc8ce4bb8de4b88de883bde5bda2e68890e5b7a6e58fb3e8b4afe9809ae8b7afe5be84e38082';
    case 'g1_title', hex = 'e5beaee69e84e4bd9331e4b889e7bbb4e5afbce794b5e7bd91e7bb9cefbc9ae4b88de5afbce9809a';
    case 'g1_sub', hex = 'e4b990e8a782e587a0e4bd95e4b88ae7958ce4b8ade4bb8de4b88de5ad98e59ca8e5b7a6e58fb3e8b4afe9809ae8b7afe5be84';
    case 'g2_title', hex = 'e5beaee69e84e4bd9332e4b889e7bbb4e5afbce794b5e7bd91e7bb9cefbc9ae5afbce9809a';
    case 'g3_title', hex = 'e5beaee69e84e4bd9333e4b889e7bbb4e5afbce794b5e7bd91e7bb9cefbc9ae5afbce9809a';
    case 'g1_legend', hex = 'e8939de889b2efbc9ae5b7a6e794b5e69e81e8bf9ee9809ae58886e9878fefbc9be6a999e889b2efbc9ae58fb3e794b5e69e81e8bf9ee9809ae58886e9878fefbc9be7b4abe889b2e8999ae7babfefbc9ae69caae7a1aee5ae9ae4bb8be8b4a8e4b990e8a782e58c85e7bb9c';
    case 'conducting_legend', hex = 'e7baa2e889b2e7b297e7babfefbc9ae5b7a6e58fb3e794b5e69e81e79c9fe5ae9ee69c80e79fade8b7afe5be84efbc9be6b585e781b0e889b2efbc9ae585b6e4bd99e594afe4b880e681a2e5a48de4bb8be8b4a8e58886e6aeb5';
    case 'overview_title', hex = 'e997aee9a29831e4b889e4b8aae5beaee69e84e4bd93e5afbce9809ae680a7e4bbbfe79c9fe7bb93e69e9c';
    case 'overview_a', hex = 'efbc8861efbc89e7bb8431efbc9ae4b88de5afbce9809a';
    case 'overview_b', hex = 'efbc8862efbc89e7bb8432efbc9ae5afbce9809a';
    case 'overview_c', hex = 'efbc8863efbc89e7bb8433efbc9ae5afbce9809a';
    case 'nanometer', hex = 'e7bab3e7b1b3';
    otherwise
        error('paperText:UnknownKey', 'Unknown paper text key: %s.', key);
end
bytes = uint8(sscanf(hex, '%2x').');
value = native2unicode(bytes, 'UTF-8');
end
