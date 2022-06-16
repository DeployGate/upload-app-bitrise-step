This pr has been generated through GitHub Actions.

<% pr_nums.each do |num| %>
- [ ] #<%= num %>
<% end %>

## Todo

- Check the pull requests above
- Merge this pull request
- Create a GitHub Release (draft) with the tag `<%= new_version %>`
- Run `bitrise run share-this-step` on your local
- Publish the Release
