Framework.Groups = Framework.Groups or {}

Framework.Groups.Types = {
    GANG = 'gang',
    ORGANIZATION = 'organization',
    GOVERNMENT = 'government',
    BUSINESS = 'business'
}

-- Rangs par défaut
Framework.Groups.DefaultRanks = {
    [0] = { name = 'Recrue', label = 'Recrue', salary = 0, permissions = {} },
    [1] = { name = 'Membre', label = 'Membre', salary = 100, permissions = { 'access_base' } },
    [2] = { name = 'Lieutenant', label = 'Lieutenant', salary = 250, permissions = { 'access_base', 'invite_members' } },
    [3] = { name = 'Chef', label = 'Chef', salary = 500, permissions = { 'access_base', 'invite_members', 'kick_members', 'manage_ranks' } }
}

-- Configuration des groupes
Framework.Groups.Config = {
    -- Gangs
    ['ballas'] = {
        name = 'ballas',
        label = 'Ballas',
        type = Framework.Groups.Types.GANG,
        color = '#663399',
        blip = { sprite = 84, color = 27 },
        maxMembers = 20,
        territory = vector3(-110.0, -1604.0, 31.0),
        ranks = Framework.Groups.DefaultRanks,
        permissions = {
            ['access_base'] = 'Accès à la base',
            ['invite_members'] = 'Inviter des membres',
            ['kick_members'] = 'Expulser des membres',
            ['manage_ranks'] = 'Gérer les rangs',
            ['access_stash'] = 'Accès au coffre',
            ['manage_vehicles'] = 'Gérer les véhicules'
        }
    },
    
    ['families'] = {
        name = 'families',
        label = 'Families',
        type = Framework.Groups.Types.GANG,
        color = '#00FF00',
        blip = { sprite = 84, color = 25 },
        maxMembers = 20,
        territory = vector3(-174.0, -1614.0, 33.0),
        ranks = Framework.Groups.DefaultRanks,
        permissions = {
            ['access_base'] = 'Accès à la base',
            ['invite_members'] = 'Inviter des membres',
            ['kick_members'] = 'Expulser des membres',
            ['manage_ranks'] = 'Gérer les rangs',
            ['access_stash'] = 'Accès au coffre',
            ['manage_vehicles'] = 'Gérer les véhicules'
        }
    },
    
    -- Organisations gouvernementales
    ['police'] = {
        name = 'police',
        label = 'LSPD',
        type = Framework.Groups.Types.GOVERNMENT,
        color = '#0066CC',
        blip = { sprite = 60, color = 29 },
        maxMembers = 50,
        territory = vector3(425.0, -979.0, 30.0),
        ranks = {
            [0] = { name = 'Cadet', label = 'Cadet', salary = 500, permissions = { 'access_base' } },
            [1] = { name = 'Officer', label = 'Officer', salary = 750, permissions = { 'access_base', 'arrest' } },
            [2] = { name = 'Sergeant', label = 'Sergeant', salary = 1000, permissions = { 'access_base', 'arrest', 'supervise' } },
            [3] = { name = 'Lieutenant', label = 'Lieutenant', salary = 1250, permissions = { 'access_base', 'arrest', 'supervise', 'manage_ranks' } },
            [4] = { name = 'Captain', label = 'Captain', salary = 1500, permissions = { 'access_base', 'arrest', 'supervise', 'manage_ranks', 'full_access' } }
        },
        permissions = {
            ['access_base'] = 'Accès au commissariat',
            ['arrest'] = 'Arrêter des suspects',
            ['supervise'] = 'Superviser les officers',
            ['manage_ranks'] = 'Gérer les rangs',
            ['full_access'] = 'Accès complet'
        }
    }
}