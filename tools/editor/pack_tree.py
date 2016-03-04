

def get_export(packs, name):
    for k, v in packs.iteritems():
        if v.get('export') == name:
            return v


def get_comp(packs, id):
    for k, v in packs.iteritems():
        if v.get('id') == id:
            return v


def id_cmp(x, y):
    return cmp(int(x), int(y))


def show_sprite(tree, root, sprite, package):
    spr_type = sprite['type']
    if spr_type == 'animation':
        ids = sprite['component'].keys()
        ids.sort(id_cmp)
        for i in ids:
            comp = sprite['component'][i]
            id = comp.get('id')
            if id == '65535':  # anchor
                name = comp['name']
                child = tree.AppendItem(root, name, ct_type=1)
                tree.CheckItem(child)
                d = tree.GetPyData(root)
                if d:
                    n = [x for x in d]
                    n.append(name)
                    tree.SetPyData(child, n)
            else:
                ref = get_comp(package, id)
                name = comp.get('name', 'index_' + id)
                child = tree.AppendItem(root, name, ct_type=1)
                d = tree.GetPyData(root)
                if d:
                    n = [x for x in d]
                    n.append(int(i) - 1)
                    tree.SetPyData(child, n)
                tree.CheckItem(child)

                ref_type = ref['type']
                if ref_type == 'animation':
                    show_sprite(tree, child, ref, package)
