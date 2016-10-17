# vim:fileencoding=utf-8

class Support
  PAYLOAD_TMPL = {
    'payload' => {
      'id' => 1,
      'number' => 1,
      'status' => nil,
      'started_at' => nil,
      'finished_at' => nil,
      'status_message' => 'Passed',
      'commit' => '62aae5f70ceee39123ef',
      'branch' => 'master',
      'message' => 'the commit message',
      'compare_url' => (
        'https://github.com/___OWNER___/minimal/compare/master...develop'
      ),
      'committed_at' => '2011-11-11T11: 11: 11Z',
      'committer_name' => 'Sven Fuchs',
      'committer_email' => 'svenfuchs@artweb-design.de',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'repository' => {
        'id' => 1,
        'name' => '___REPO___',
        'owner_name' => '___OWNER___',
        'url' => 'http://github.com/___OWNER___/minimal'
      },
      'matrix' => [
        {
          'id' => 2,
          'repository_id' => 1,
          'number' => '1.1',
          'state' => 'created',
          'started_at' => nil,
          'finished_at' => nil,
          'config' => {
            'notifications' => {
              'webhooks' => [
                'http://evome.fr/notifications',
                'http://example.com/'
              ]
            }
          },
          'status' => nil,
          'log' => '',
          'result' => nil,
          'parent_id' => 1,
          'commit' => '62aae5f70ceee39123ef',
          'branch' => 'master',
          'message' => 'the commit message',
          'committed_at' => '2011-11-11T11: 11: 11Z',
          'committer_name' => 'Sven Fuchs',
          'committer_email' => 'svenfuchs@artweb-design.de',
          'author_name' => 'Sven Fuchs',
          'author_email' => 'svenfuchs@artweb-design.de',
          'compare_url' =>
            'https://github.com/___OWNER___/minimal/compare/master...develop'

        }
      ]
    }
  }.freeze

  def self.valid_payload(owner = 'foo', repo = 'bar')
    PAYLOAD_TMPL.clone.tap do |payload|
      substitute_payload_vars!(payload['payload'], owner, repo)
    end
  end

  def self.substitute_payload_vars!(payload, owner, repo)
    payload['compare_url'] = payload['compare_url'].sub(/___OWNER___/, owner)
    payload['repository'].merge!(
      'name' => repo,
      'owner_name' => owner,
      'url' => payload['repository']['url'].sub(/___OWNER___/, owner)
    )
    compare_url = payload['matrix'].first['compare_url']
    payload['matrix'].first.merge!(
      'compare_url' => compare_url.sub(/___OWNER___/, owner)
    )
  end
end
