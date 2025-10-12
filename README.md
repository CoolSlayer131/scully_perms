# Scully Perms
<img width="900" height="150" alt="image" src="https://raw.githubusercontent.com/Scullyy/scully_perms/refs/heads/main/images/banner.png" />

A lightweight permissions system for FiveM servers to manage role-based permissions efficiently.

# Support
Join our [Discord](https://discord.gg/scully) server for help, updates, and community discussions.

## Features
- Easy permission checking
- Supports single and multiple permission checks
- Integrates seamlessly with FiveM's ACE system
- Optional discord membership with adaptive card
- Optional age verification

## Installation
1. Download and add the `scully_perms` resource to your server's `resources` folder.
2. Add the following lines to your `server.cfg`:

```cfg
ensure scully_perms

add_ace resource.scully_perms command.add_principal allow
add_ace resource.scully_perms command.remove_principal allow
```

3. Restart your server.

## Preview
<img alt="image" src="https://raw.githubusercontent.com/Scullyy/scully_perms/refs/heads/main/images/preview.png" />

## Usage
You can verify if a player has specific permissions using the provided exports. These can be called from other resources.

### Single Permission Check
Check if a player has a single permission.
```lua
if exports.scully_perms:hasPermission(source, 'permission') then
    print('Has permissions!')
else
    print('Does not have permissions!')
end
```

### Multiple Permission Check
Check if a player has all or some of the specified permissions:
```lua
if exports.scully_perms:hasPermission(source, {'permission1', 'permission2', 'permission3'}) then
    print('Has permissions!')
else
    print('Does not have permissions!')
end
```

# License
This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## ⭐ If you found this useful, consider starring the repo! Contributions welcome via pull requests. ⭐
