Router.route('/', function () {
  this.render('home');
  SEO.set({ title: 'PPHaitao -' + Meteor.App.NAME });
});
