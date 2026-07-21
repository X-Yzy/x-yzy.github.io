Jekyll::Hooks.register :site, :post_read do |site|
  locales = site.data['locales']
  locale = locales[site.config['lang']]
  english = locales['en']

  %w[layout tabs search panel theme post categories].each do |section|
    locale[section] = english[section] if english[section]
  end

  license = locale.dig('copyright', 'license')
  license.delete('template') if license
end

Jekyll::Hooks.register :posts, :post_init do |post|
  commit_num = `git rev-list --count HEAD "#{post.path}"`
  if commit_num.to_i > 1
    lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{post.path}"`
    post.data['last_modified_at'] = lastmod_date
  end
end
